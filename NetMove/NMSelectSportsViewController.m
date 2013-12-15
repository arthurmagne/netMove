//
//  NMSelectSportsViewController.m
//  NetMove
//
//  Created by arthur magne on 07/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import "NMSelectSportsViewController.h"
#import "Sport.h"
#import "StackMob.h"
#import "SMDataStore.h"
#import "AppDelegate.h"
#import "NMSetLocationViewController.h"

@interface NMSelectSportsViewController ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSArray *sports;

@end

@implementation NMSelectSportsViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize sports = _sports;
@synthesize userId = _userId;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}
// We know who is connected with this id,
// In this view we need to add the selected sports to this user
// Maybe create a new crosstable between user and sport 
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"l'id récupéré est %@", self.userId);
    
    self.managedObjectContext = [[self.appDelegate coreDataStore] contextForCurrentThread];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    [refreshControl addTarget:self action:@selector(loadSports) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl  = refreshControl;
    
    [refreshControl beginRefreshing];
    
    [self loadSports];
    


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)loadSports {

    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sport" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    [self.managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
        [self.refreshControl endRefreshing];
        self.sports = results;
        [self.tableView reloadData];
        
    } onFailure:^(NSError *error) {
        
        [self.refreshControl endRefreshing];
        NSLog(@"An error %@, %@", error, [error userInfo]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.sports count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SportCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SportCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    Sport *sport = [self.sports objectAtIndex:indexPath.row];
    cell.textLabel.text = sport.sport_name;
    
    if (sport.isSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    Sport *sport = [self.sports objectAtIndex:indexPath.row];
    sport.isSelected = !sport.isSelected;

    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)doneBtn:(id)sender {
    NSMutableArray *selectedSportsTmp = [[NSMutableArray alloc] init];
    for (Sport *sport in self.sports) {
        if (sport.isSelected){
            // we add the sport id
            [selectedSportsTmp addObject:sport.sport_id];

        }
    }

    // we add nil to this mutableArray
    //[selectedSportsTmp addObject:[NSNull nil]];

    NSArray *selectedSports = [NSArray arrayWithArray:selectedSportsTmp];
    //NSArray *selectedSports = [NSArray arrayWithObjects:@"26a8ab9253f343ecbb227c2e1b6d23ba", nil];
    
    [[[SMClient defaultClient] dataStore] appendObjects:selectedSports toObjectWithId:self.userId inSchema:@"user" field:@"sports" onSuccess:^(NSDictionary* object, NSString *schema) {
        // object contains the parent object dictionary
        NSLog(@"la mise a jour des données (sports) a réussi");
        [self performSegueWithIdentifier:@"sportSelectedSegue" sender:self];


    } onFailure:^(NSError *error, NSString *objectId, NSString *schema) {
        // Handle error
        NSLog(@"la mise a jour des données (sports) a échoué");
    }];

    

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // [context objectWithID:objectID]; to get the full NSManagedObject
    
    if ([[segue identifier] isEqualToString:@"sportSelectedSegue"]) {
        
        // Get destination view
        NMSetLocationViewController *setLocationView = [segue destinationViewController];
        // pass the NSManagedObjectID (the id of our user)
        NSLog(@"le self.userId est : %@", self.userId);
        [setLocationView setUserId:self.userId];
        
    }
    
}


@end





